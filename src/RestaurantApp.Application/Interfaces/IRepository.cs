using System.Linq.Expressions;

namespace RestaurantApp.Application.Interfaces;

public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(int id, bool asNoTracking = true);
    Task<IEnumerable<T>> GetAllAsync(bool asNoTracking = true);
    Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate, bool asNoTracking = true);
    Task AddAsync(T entity);
    void Update(T entity);
    void Remove(T entity);
}
