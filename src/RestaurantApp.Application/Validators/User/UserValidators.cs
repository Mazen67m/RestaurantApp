using FluentValidation;
using RestaurantApp.Application.DTOs.User;

namespace RestaurantApp.Application.Validators.User;

public class CreateUserDtoValidator : AbstractValidator<CreateUserDto>
{
    public CreateUserDtoValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty()
            .WithMessage("Email is required")
            .EmailAddress()
            .WithMessage("Invalid email format")
            .MaximumLength(256)
            .WithMessage("Email must not exceed 256 characters");

        RuleFor(x => x.Password)
            .NotEmpty()
            .WithMessage("Password is required")
            .MinimumLength(12)
            .WithMessage("Password must be at least 12 characters")
            .MaximumLength(100)
            .WithMessage("Password must not exceed 100 characters");

        RuleFor(x => x.FullName)
            .NotEmpty()
            .WithMessage("Full name is required")
            .MinimumLength(2)
            .WithMessage("Full name must be at least 2 characters")
            .MaximumLength(100)
            .WithMessage("Full name must not exceed 100 characters");

        RuleFor(x => x.Phone)
            .Matches(@"^\+?[1-9]\d{1,14}$")
            .When(x => !string.IsNullOrEmpty(x.Phone))
            .WithMessage("Invalid phone number format");

        RuleFor(x => x.Role)
            .Must(role => string.IsNullOrEmpty(role) || 
                         new[] { "Customer", "Admin", "SuperAdmin", "Cashier", "DeliveryDriver" }.Contains(role))
            .WithMessage("Invalid role. Must be one of: Customer, Admin, SuperAdmin, Cashier, DeliveryDriver");
    }
}

public class UpdateUserDtoValidator : AbstractValidator<UpdateUserDto>
{
    public UpdateUserDtoValidator()
    {
        RuleFor(x => x.FullName)
            .MinimumLength(2)
            .When(x => !string.IsNullOrEmpty(x.FullName))
            .WithMessage("Full name must be at least 2 characters")
            .MaximumLength(100)
            .When(x => !string.IsNullOrEmpty(x.FullName))
            .WithMessage("Full name must not exceed 100 characters");

        RuleFor(x => x.Phone)
            .Matches(@"^\+?[1-9]\d{1,14}$")
            .When(x => !string.IsNullOrEmpty(x.Phone))
            .WithMessage("Invalid phone number format");

        RuleFor(x => x.Role)
            .Must(role => string.IsNullOrEmpty(role) || 
                         new[] { "Customer", "Admin", "SuperAdmin", "Cashier", "DeliveryDriver" }.Contains(role))
            .When(x => !string.IsNullOrEmpty(x.Role))
            .WithMessage("Invalid role. Must be one of: Customer, Admin, SuperAdmin, Cashier, DeliveryDriver");
    }
}
