{ pkgs, ... }: {
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # This service account gives read-only access to a nearly empty vault in Savanni's account. The only valid path in this account is ""op://Nixops Hackathon/Login/password"".
    environment.etc."op-service-account-token".text = "ops_eyJzaWduSW5BZGRyZXNzIjoibXkuMXBhc3N3b3JkLmNvbSIsInVzZXJBdXRoIjp7Im1ldGhvZCI6IlNSUGctNDA5NiIsImFsZyI6IlBCRVMyZy1IUzI1NiIsIml0ZXJhdGlvbnMiOjY1MDAwMCwic2FsdCI6IkFMQjFRbGdmdXBmVnNqOEVMVEtYM0EifSwiZW1haWwiOiI1YTV4M2M3NHlvd2t1QDFwYXNzd29yZHNlcnZpY2VhY2NvdW50cy5jb20iLCJzcnBYIjoiOTJjYWMzYTBhZGNjYzIzMDY4ZWUyYTc1MjI5ZDgyZDQyODFmMjc1Mzc2ZTI5ZWE3MzM0YWI4Nzg3MTc5NDRkOSIsIm11ayI6eyJhbGciOiJBMjU2R0NNIiwiZXh0Ijp0cnVlLCJrIjoieU1xSEMzaTFIMkoyWEVYdzd4cjRtVE55b2R5RkN1b2taekRrMWhoVUhPQSIsImtleV9vcHMiOlsiZW5jcnlwdCIsImRlY3J5cHQiXSwia3R5Ijoib2N0Iiwia2lkIjoibXAifSwic2VjcmV0S2V5IjoiQTMtUVlKVEE4LURRSk02QS1HSDVFVy03WkJBUy1aVkRURi1RMkVZUyIsInRocm90dGxlU2VjcmV0Ijp7InNlZWQiOiJmY2U2MjEzNDc5YmE3ZDRmZjE2OTc1NmExZjE2YWY5YjA4YzViY2RjYzNjOWMzNmQzYTg4ZjhmNWQ2NjM5Njg2IiwidXVpZCI6IlhPRzVVVkxNNkpDR0hBV042NE9SQURTTzVNIn0sImRldmljZVV1aWQiOiJnbHhhYTRuZHdmMmN6aDZ0YjM3NmF0YnlqYSJ9";

    # opnix = {
    #     serviceAccountTokenPath = "/etc/op-service-account-token";
    #     secrets = {
    #         homepage-config.source = ''
    #             HOMEPAGE_TEST_SECRET="{{ op://Service Account Testing/Login/password }}"
    #         '';
    #     };
    # };
}
