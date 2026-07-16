SELECT *
FROM (
    SELECT
        d.d_year,
        s.s_state,
        i.i_category,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_paid) DESC) AS rn
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
    GROUP BY d.d_year, s.s_state, i.i_category
) t
WHERE t.rn <= 5
ORDER BY t.d_year, t.total_net_paid DESC
