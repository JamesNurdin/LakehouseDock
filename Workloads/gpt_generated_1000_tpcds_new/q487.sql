WITH base AS (
    SELECT
        cp.cp_department,
        d.d_year,
        cs.cs_net_paid,
        cs.cs_order_number,
        cs.cs_quantity,
        cr.cr_return_amount,
        ws.ws_net_paid_inc_ship
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND cp.cp_department = 'Books'
      AND ws.ws_net_paid_inc_ship > 2000
      AND cr.cr_return_amount > 100
),
agg AS (
    SELECT
        cp_department,
        d_year,
        SUM(cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM base
    WHERE cs_order_number IN (
        SELECT cs_order_number FROM catalog_sales WHERE cs_quantity > 5
        INTERSECT
        SELECT cr_order_number FROM catalog_returns WHERE cr_return_amount > 200
    )
    GROUP BY cp_department, d_year
    HAVING SUM(cs_net_paid) > 10000
)
SELECT
    cp_department,
    d_year,
    total_net_paid,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_net_paid DESC) AS dept_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
