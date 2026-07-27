WITH returns_2001 AS (
        SELECT sr.sr_store_sk,
               sr.sr_net_loss,
               sr.sr_returned_date_sk
        FROM store_returns sr
        WHERE sr.sr_returned_date_sk IN (
                SELECT d_date_sk
                FROM date_dim d
                WHERE d.d_year = 2001
              )
      ),
     store_info AS (
        SELECT s.s_store_sk,
               s.s_store_name,
               s.s_number_employees,
               CONCAT(s.s_state, '-', s.s_city) AS location
        FROM store s
      ),
     base AS (
        SELECT si.s_store_name,
               si.location,
               CASE
                 WHEN si.s_number_employees > 500 THEN 'Large'
                 WHEN si.s_number_employees > 200 THEN 'Medium'
                 ELSE 'Small'
               END AS store_size,
               SUM(r.sr_net_loss) AS total_net_loss
        FROM returns_2001 r
        JOIN store_info si ON r.sr_store_sk = si.s_store_sk
        JOIN date_dim d ON r.sr_returned_date_sk = d.d_date_sk
        JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
        WHERE regexp_like(ws.web_name, '(?i)shop')
          AND ws.web_class LIKE 'U%'
        GROUP BY si.s_store_name,
                 si.location,
                 CASE
                   WHEN si.s_number_employees > 500 THEN 'Large'
                   WHEN si.s_number_employees > 200 THEN 'Medium'
                   ELSE 'Small'
                 END
      )
SELECT b.s_store_name,
       b.location,
       b.store_size,
       b.total_net_loss,
       CASE
         WHEN b.total_net_loss > (
                SELECT AVG(sr_net_loss)
                FROM store_returns
                WHERE sr_returned_date_sk IN (
                        SELECT d_date_sk
                        FROM date_dim
                        WHERE d_year = 2001
                      )
              ) THEN 'Above Avg'
         ELSE 'Below Avg'
       END AS loss_category
FROM base b
ORDER BY b.total_net_loss DESC
LIMIT 100
