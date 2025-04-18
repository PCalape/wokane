import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginUserDto } from './dto/login-user.dto';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService
  ) {}

  async register(registerDto: CreateUserDto): Promise<void> {
    await this.usersService.createUser(registerDto);
  }

  async login(loginUserDto: LoginUserDto): Promise<{ accessToken: string }> {
    try {
      const user = await this.usersService.validateUserPassword(loginUserDto);

      const payload = { email: user.email, id: user._id };
      const accessToken = this.jwtService.sign(payload);

      return { accessToken };
    } catch (error) {
      throw new UnauthorizedException('Invalid credentials');
    }
  }
}
