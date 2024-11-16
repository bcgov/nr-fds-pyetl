"""
Wrapper to object storage functionality.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import pathlib

import logging
import pathlib

import boto3
import botocore.exceptions
import constants
import env_config

LOGGER = logging.getLogger(__name__)


class OStore:
    """
    Wrapper for object store functionality.
    """

    def __init__(
        self,
        conn_params: env_config.ObjectStoreParameters,
    ) -> None:
        """
        Contruct object store wrapper.

        :param conn_params: connection parameters to communicate with object
            storage
        :type conn_params: env_config.ObjectStoreParameters
        """
        self.conn_params = conn_params
        self.s3_client = boto3.client(
            "s3",
            aws_access_key_id=self.conn_params.user_id,
            aws_secret_access_key=self.conn_params.secret,
            endpoint_url=f"https://{self.conn_params.host}",
        )

    def get_data_files(
        self, tables: list[str], env_str: str, db_type: constants.DBType
    ) -> None:
        """
        Pull data files from object store.

        :param tables: list of tables who's corresonding data files are to be
            pulled
        :type tables: list[str]
        """
        ostore_dir = constants.get_export_ostore_path(db_type)
        remote_files = self.s3_client.list_objects(
            Bucket=self.conn_params.bucket,
            Prefix=str(ostore_dir),
        )
        remote_file_names = [
            remote_file["Key"] for remote_file in remote_files["Contents"]
        ]
        LOGGER.debug("remote files: %s", remote_file_names)

        for table in tables:
            local_data_file = constants.get_parquet_file_path(
                table, env_str, db_type
            )
            remote_data_file = constants.get_parquet_file_ostore_path(
                table,
                db_type,
            )
            # Added logic to use csv if parquet fails... So if the parquet file
            # doesn't exist get the csv file instead.
            LOGGER.debug("remote_data_file: %s", str(remote_data_file))
            if str(remote_data_file) not in remote_file_names:
                remote_data_file = remote_data_file.with_suffix(
                    constants.SQL_DUMP_SUFFIX
                )
                local_data_file = local_data_file.with_suffix(
                    constants.SQL_DUMP_SUFFIX
                )

            # keeping it simple for now, if local exists re-use it
            if not local_data_file.exists():
                # pull the files from object store.
                # with Path("f1.py").open("wb") as fp:
                with local_data_file.open("wb") as f:
                    # with open(local_data_file, "wb") as f:
                    self.s3_client.download_fileobj(
                        self.conn_params.bucket,
                        str(remote_data_file),
                        f,
                    )

    def object_exists(self, object_name: str) -> bool:
        """
        Test to see if object exists in object storage.

        Looks for an object with the key/prefix/object name in the bucket, and
        returns true if it exists.

        :param object_name: name or prefix of the object that we are testing for
        :type object_name: str
        :return: boolean indicating if there is an object in the bucket with
            that name
        :rtype: bool
        """
        try:
            self.s3_client.get_object(
                Bucket=self._bucket,
                Key=object_name,
            )
            return True  # noqa: TRY300
        except self.s3_client.exceptions.NoSuchKey:
            return False

    def delete_data_file(self, object_store_file: pathlib.Path) -> None:
        """
        delete object that matches the supplied name.

        If an object with the name `object_store_file` exists it will be deleted

        :param object_store_file: name of the object store file
        :type object_store_file: str
        """
        LOGGER.debug("object store path: %s", object_store_file)
        versions = self.get_object_versions(object_store_file)
        for version in versions:
            LOGGER.debug("version: %s", version)
            try:
                response = self.s3_client.delete_object(
                    Bucket=self.conn_params.bucket,
                    Key=str(object_store_file),
                    VersionId=version["VersionId"],
                )
                LOGGER.debug("delete operation response: %s", response)
            except botocore.exceptions.NoCredentialsError:
                LOGGER.exception("Credentials not available.")
            except botocore.exceptions.PartialCredentialsError:
                LOGGER.exception("Incomplete credentials provided.")
            except self.s3_client.exceptions.NoSuchKey:
                LOGGER.exception(
                    "The object with key '%s' does not exist in bucket '%s'.",
                    object_store_file,
                    self.conn_params.bucket,
                )

    def get_object_versions(self, object_store_file: str) -> list[dict]:
        """
        Retrieve the versions for the given object_store_file.

        Queries the object store for all the versions that are associated with
        the `object_store_file`, and returns a list of the version payload.

        :param object_store_file: object prefix/key/name who's versions we want
            retrieved.
        :type object_store_file: str
        :return: a list of version dictionaries that are extracted from object
            store.
        :rtype: list[dict]

        sample of a dictionary return type
            {'ETag': '"9fa5c1658302075a8a648143861e24fd"',
             'Size': 3985,
             'StorageClass': 'STANDARD',
             'Key': 'pyetl/BEC_VERSION_CONTROL.parquet',
             'VersionId': '1728653254070',
             'IsLatest': False,
             'LastModified': datetime.datetime(2024, 10, 11, 14, 50, 54, 70000,
                                               tzinfo=tzutc()),
             'Owner': {
                'DisplayName': 'billbarilco_tst',
                'ID': 'billbarilco_tst'}}
        """
        versions = []
        try:
            LOGGER.debug("object store path: %s", str(object_store_file))
            response = self.s3_client.list_object_versions(
                Bucket=self.conn_params.bucket,
                Prefix=str(object_store_file),
            )
            versions = response.get("Versions", [])
        except botocore.exceptions.NoCredentialsError:
            LOGGER.exception("Credentials not available.")
        except botocore.exceptions.PartialCredentialsError:
            LOGGER.exception("Incomplete credentials provided.")
        except self.s3_client.exceptions.NoSuchKey:
            LOGGER.exception(
                "The object with key '%s' does not exist in bucket '%s'.",
                object_store_file,
                self.conn_params.bucket,
            )
        return versions

    def put_data_files(
        self, tables: list[str], env_str: str, db_type: constants.DBType
    ) -> None:
        """
        Upload files that correspond with tables to object storage.

        Gets a list of tables, iterates over them, for each table retrieves the
        expected name of the corresponding table in object store, also retrieves
        the expected location of the files locally, and then uploads the local
        files.

        :param tables: List of table names who's corresponding parquet data
            files should be uploaded to object store.
        :type tables: list[str]
        :param env_str: an environment string like LOCAL/DEV/TEST/PROD
        :type env_str: str
        """
        for table in tables:
            local_data_file = constants.get_default_export_file_path(
                table, env_str, db_type
            )
            remote_data_file = constants.get_default_export_file_ostore_path(
                table,
                db_type,
            )

            # keeping it simple for now, if local exists re-use it
            if local_data_file.exists():
                self.delete_data_file(remote_data_file)
                # pull the files from object store.
            response = self.s3_client.upload_file(
                str(local_data_file),
                self.conn_params.bucket,
                str(remote_data_file),
            )
            LOGGER.debug("response from object store upload: %s", response)


if __name__ == "__main__":

    env = env_config.Env("TEST")
    file = "tmp_file"
    ostore_creds = env.get_ostore_constants()
    ostore = OStore(ostore_creds)

    table = "BEC_VERSION_CONTROL"
    ostore.put_data_files([table], env.current_env)
    ostore.get_data_files([table], env.current_env)
