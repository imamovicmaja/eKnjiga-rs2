using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eKnjiga.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BaseCRUDController<T, TSearch, TInsert, TUpdate> 
        : BaseController<T, TSearch>
        where T : class
        where TSearch : BaseSearchObject, new()
        where TInsert : class
        where TUpdate : class
    {
        protected readonly ICRUDService<T, TSearch, TInsert, TUpdate> _crudService;

        public BaseCRUDController(ICRUDService<T, TSearch, TInsert, TUpdate> service)
            : base(service)
        {
            _crudService = service;
        }

        [HttpPost]
        public virtual async Task<ActionResult<T>> Create([FromBody] TInsert request)
        {
            try
            {
                var result = await _crudService.CreateAsync(request);
                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("{id}")]
        public virtual async Task<ActionResult<T?>> Update(int id, [FromBody] TUpdate request)
        {
            try
            {
                var result = await _crudService.UpdateAsync(id, request);

                if (result == null)
                    return NotFound(new { message = "Entity not found." });

                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public virtual async Task<ActionResult> Delete(int id)
        {
            try
            {
                var success = await _crudService.DeleteAsync(id);

                if (!success)
                    return NotFound(new { message = "Entity not found." });

                return NoContent();
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
