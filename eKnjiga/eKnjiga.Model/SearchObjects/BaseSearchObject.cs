using System;

namespace eKnjiga.Model.SearchObjects
{
    public class BaseSearchObject
    {
        private const int MaxPageSize = 50;

        public int Page { get; set; } = 1;

        private int _pageSize = 10;

        public int PageSize
        {
            get => _pageSize;
            set => _pageSize = value <= 0 ? 10 : Math.Min(value, MaxPageSize);
        }

        public bool IncludeTotalCount { get; set; } = false;
    }
}