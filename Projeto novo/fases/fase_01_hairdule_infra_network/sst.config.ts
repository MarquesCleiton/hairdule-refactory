/// <reference path="./.sst/platform/config.d.ts" />

export default $config({
  app(input) {
    return {
      name: "hairdule-infra-network",
      removal: input?.stage === "production" ? "retain" : "remove",
      home: "aws",
      providers: {
        aws: {
          region: "us-east-1"
        }
      }
    };
  },
  async run() {
    // VPC com 2 Zonas de Disponibilidade em N. Virginia (us-east-1a e us-east-1b)
    const vpc = new sst.aws.Vpc("HairduleVpc", {
      az: 2,
      nat: "managed",
    });

    return {
      vpcId: vpc.id,
      publicSubnets: vpc.publicSubnets,
      privateSubnets: vpc.privateSubnets,
    };
  },
});
