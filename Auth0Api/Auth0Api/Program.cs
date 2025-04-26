using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;

var builder = WebApplication.CreateBuilder(args);

// --- CORS Konfiguration ---
var flutterAppOrigin = "http://localhost:5000";
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterApp",
        policy =>
        {
            policy.WithOrigins(flutterAppOrigin)
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        });
});

// --- Authentifizierung Konfiguration ---
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(options =>
{
    options.Authority = "https://dev-u5cia72lx8dok4is.us.auth0.com/";

    options.Audience = "https://localhost:7294/";
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            // Hier wird der Token abgerufen
            var token = context.Request.Headers["Authorization"].ToString();

            // Breakpoint setzen und Debuggen
            Console.WriteLine($"Token (OnMessageReceived): {token}");

            return Task.CompletedTask;
        }
    };

    options.TokenValidationParameters = new TokenValidationParameters
    {
        NameClaimType = ClaimTypes.NameIdentifier
    };
});

builder.Services.AddAuthorization();


builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseRouting();

app.UseCors("AllowFlutterApp");

app.UseAuthentication();
app.UseAuthorization();


app.MapControllers();

app.Run();