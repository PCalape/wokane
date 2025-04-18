import { MongoMemoryServer } from 'mongodb-memory-server';
import { connect, Connection, disconnect } from 'mongoose';

export class TestDatabaseSetup {
  private mongod: MongoMemoryServer;
  private mongoConnection: Connection;
  private mongoUri: string;

  constructor() {
    this.mongod = null as unknown as MongoMemoryServer;
    this.mongoConnection = null as unknown as Connection;
    this.mongoUri = '';
  }

  async setupDatabase() {
    this.mongod = await MongoMemoryServer.create();
    this.mongoUri = this.mongod.getUri();

    const mongooseOpts = {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    };

    this.mongoConnection = (await connect(this.mongoUri)).connection;
  }

  async closeDatabase() {
    await this.mongoConnection.dropDatabase();
    await this.mongoConnection.close();
    await this.mongod.stop();
    await disconnect();
  }

  async clearDatabase() {
    const collections = this.mongoConnection.collections;
    for (const key in collections) {
      const collection = collections[key];
      await collection.deleteMany({});
    }
  }

  getMongoUri() {
    return this.mongoUri;
  }
}
