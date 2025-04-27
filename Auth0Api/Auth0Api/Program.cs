using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;

var builder = WebApplication.CreateBuilder(args);

var authenticationSettings = builder.Configuration.GetSection("Auth0");


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
    options.Authority = authenticationSettings["Domain"];

    options.Audience = authenticationSettings["Audience"];
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
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "AuthDemo API",
        Version = "v1"
    });

    // Sicherheitsdefinition für JWT
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Description = "Geben Sie den JWT-Token ein. Beispiel: Bearer {token}"
    });

    // Sicherheitsanforderungen
    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});
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