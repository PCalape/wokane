import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginUserDto } from './dto/login-user.dto';
import { ObjectId } from 'mongoose';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService
  ) {}

  async register(registerDto: CreateUserDto): Promise<void> {
    await this.usersService.createUser(registerDto);
  }

  async login(
    authCredentialsDto: LoginUserDto
  ): Promise<{ accessToken: string }> {
    try {
      const user =
        await this.usersService.validateUserPassword(authCredentialsDto);

      // Make sure we use _id as id in the payload for consistency
      const payload = {
        email: user.email,
        id: (<ObjectId>user._id).toString(),
      };
      const accessToken = this.jwtService.sign(payload);

      return { accessToken };
    } catch (error) {
      throw new UnauthorizedException('Invalid credentials');
    }
  }
}
