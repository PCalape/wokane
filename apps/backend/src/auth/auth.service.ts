import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { AuthCredentialsDto } from './dto/auth-credentials.dto';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService
  ) {}

  async register(authCredentialsDto: AuthCredentialsDto): Promise<void> {
    const { username, password } = authCredentialsDto;
    await this.usersService.createUser({ username, password });
  }

  async login(
    authCredentialsDto: AuthCredentialsDto
  ): Promise<{ accessToken: string }> {
    const { username, password } = authCredentialsDto;
    const user = await this.usersService.validateUser(username, password);
    if (!user) {
      throw new Error('Invalid credentials');
    }
    const accessToken = this.jwtService.sign({
      username: user.username,
      id: user._id,
    });
    return { accessToken };
  }
}
