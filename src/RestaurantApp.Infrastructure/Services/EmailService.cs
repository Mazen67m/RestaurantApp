using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using RestaurantApp.Application.Interfaces;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using MimeKit.Text;

namespace RestaurantApp.Infrastructure.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task SendEmailVerificationAsync(string email, string token)
    {
        var subject = "Verify Your Email - Restaurant App";
        var body = $@"
            <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;'>
                <h2 style='color: #e67e22;'>Welcome to Restaurant App!</h2>
                <p>Thank you for registering. Please use the following token to verify your email address:</p>
                <div style='background: #f9f9f9; padding: 15px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 5px; color: #2c3e50; border-radius: 5px; border: 1px dashed #bdc3c7;'>
                    {token}
                </div>
                <p style='margin-top: 20px;'>If you did not create an account, no further action is required.</p>
                <hr style='border: 0; border-top: 1px solid #eee; margin: 20px 0;'>
                <p style='font-size: 12px; color: #7f8c8d; text-align: center;'>&copy; {DateTime.UtcNow.Year} Restaurant App. All rights reserved.</p>
            </div>";

        await SendEmailAsync(email, subject, body);
    }

    public async Task SendPasswordResetAsync(string email, string token)
    {
        var subject = "Reset Your Password - Restaurant App";
        var body = $@"
            <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;'>
                <h2 style='color: #e67e22;'>Password Reset Request</h2>
                <p>We received a request to reset your password. Please use the following token to proceed:</p>
                <div style='background: #f9f9f9; padding: 15px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 5px; color: #c0392b; border-radius: 5px; border: 1px dashed #bdc3c7;'>
                    {token}
                </div>
                <p style='margin-top: 20px; color: #7f8c8d;'>This token will expire in 1 hour. If you didn't request this, you can safely ignore this email.</p>
                <hr style='border: 0; border-top: 1px solid #eee; margin: 20px 0;'>
                <p style='font-size: 12px; color: #7f8c8d; text-align: center;'>&copy; {DateTime.UtcNow.Year} Restaurant App. All rights reserved.</p>
            </div>";

        await SendEmailAsync(email, subject, body);
    }

    public async Task SendOrderConfirmationAsync(string email, string orderNumber, decimal total)
    {
        var subject = $"Order Confirmed #{orderNumber} - Restaurant App";
        var body = $@"
            <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;'>
                <h2 style='color: #27ae60;'>Great News! Your order is confirmed.</h2>
                <p>Order Number: <strong>#{orderNumber}</strong></p>
                <p>We've received your order and our kitchen is starting to prepare it.</p>
                <div style='background: #f1f2f6; padding: 15px; border-radius: 5px; margin: 20px 0;'>
                    <span style='font-size: 18px;'>Order Total: <strong>${total:F2}</strong></span>
                </div>
                <p>You can track your order status in the app.</p>
                <hr style='border: 0; border-top: 1px solid #eee; margin: 20px 0;'>
                <p style='text-align: center; color: #e67e22; font-weight: bold;'>Enjoy your meal!</p>
            </div>";

        await SendEmailAsync(email, subject, body);
    }

    public async Task SendOrderStatusUpdateAsync(string email, string orderNumber, string status)
    {
        var subject = $"Update on your Order #{orderNumber}";
        var body = $@"
            <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;'>
                <h2 style='color: #2980b9;'>Order Status Update</h2>
                <p>Your order <strong>#{orderNumber}</strong> has a new status:</p>
                <div style='background: #eaf2f8; padding: 20px; text-align: center; font-size: 20px; font-weight: bold; color: #2980b9; border-radius: 5px;'>
                    {status.ToUpper()}
                </div>
                <p style='margin-top: 20px;'>Check the app for real-time tracking.</p>
                <hr style='border: 0; border-top: 1px solid #eee; margin: 20px 0;'>
                <p style='font-size: 12px; color: #7f8c8d; text-align: center;'>Thank you for choosing Restaurant App!</p>
            </div>";

        await SendEmailAsync(email, subject, body);
    }

    private async Task SendEmailAsync(string to, string subject, string htmlBody)
    {
        try
        {
            var email = new MimeMessage();
            email.From.Add(new MailboxAddress(
                _configuration["Smtp:SenderName"], 
                _configuration["Smtp:SenderEmail"]));
            email.To.Add(MailboxAddress.Parse(to));
            email.Subject = subject;
            email.Body = new TextPart(TextFormat.Html) { Text = htmlBody };

            using var smtp = new SmtpClient();
            
            // Log connection details (without sensitive info)
            _logger.LogInformation("Connecting to SMTP server {Server}:{Port}", 
                _configuration["Smtp:Server"], _configuration["Smtp:Port"]);

            await smtp.ConnectAsync(
                _configuration["Smtp:Server"], 
                int.Parse(_configuration["Smtp:Port"] ?? "587"), 
                SecureSocketOptions.StartTls);

            await smtp.AuthenticateAsync(
                _configuration["Smtp:Username"], 
                _configuration["Smtp:Password"]);

            await smtp.SendAsync(email);
            await smtp.DisconnectAsync(true);

            _logger.LogInformation("Successfully sent email to {To} with subject: {Subject}", to, subject);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send email to {To}. Error: {Message}", to, ex.Message);
            // Re-throw so Hangfire can retry
            throw;
        }
    }
}
