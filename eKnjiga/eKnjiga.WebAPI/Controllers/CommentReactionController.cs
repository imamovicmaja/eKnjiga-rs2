using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace eKnjiga.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CommentReactionController : ControllerBase
    {
        private readonly ICommentReactionService _commentReactionService;

        public CommentReactionController(ICommentReactionService commentReactionService)
        {
            _commentReactionService = commentReactionService;
        }

        [HttpGet]
        public async Task<PagedResult<CommentReactionResponse>> Get([FromQuery] CommentReactionSearchObject? search = null)
        {
            return await _commentReactionService.GetAsync(search ?? new CommentReactionSearchObject());
        }

        [HttpPost]
        public async Task<ActionResult<CommentReactionResponse>> React([FromBody] CommentReactionRequest request)
        {
            var result = await _commentReactionService.CreateOrUpdateReactionAsync(request);
            return Ok(result);
        }

        [HttpDelete]
        public async Task<IActionResult> RemoveReaction([FromBody] CommentReactionRequest request)
        {
            var success = await _commentReactionService.RemoveReactionAsync(request);
            if (success)
                return Ok(new { message = "Reaction removed." });

            return NotFound(new { message = "Reaction not found." });
        }
    }
}
