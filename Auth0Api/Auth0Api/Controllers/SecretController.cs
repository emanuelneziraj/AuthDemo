using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
namespace Auth0Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SecretController : ControllerBase
{
    [HttpGet]
    [Authorize]
    public IActionResult GetSecretData()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        return Ok(new { Message = $"Hallo User {userId}! Dies sind geheime Daten von der API. Uhrzeit: {DateTime.UtcNow}" });
    }

    [HttpGet("public")]
    public IActionResult GetPublicData()
    {
        return Ok(new { Message = "Dies sind öffentliche Daten. Jeder kann sie sehen." });
    }
}