WITH base AS (
    SELECT
        cp.cp_department AS department,
        r.r_reason_desc AS reason_desc,
        cs.cs_net_profit,
        cr.cr_return_amount,
        cp.cp_type,
        cr.cr_store_credit,
        c.c_birth_year,
        cs.cs_quantity,
        t_sold.t_time_sk AS sold_time_sk,
        t_ret.t_time_sk AS return_time_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
    JOIN time_dim t_ret
      ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cp.cp_type = 'monthly'
      AND cr.cr_store_credit > 10
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND cs.cs_quantity > 1
),
agg AS (
    SELECT
        department,
        reason_desc,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cs_net_profit) AS total_net_profit,
        CASE WHEN SUM(cs_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign,
        GROUPING(department) AS g_dept,
        GROUPING(reason_desc) AS g_reason
    FROM base
    GROUP BY GROUPING SETS (
        (department, reason_desc),
        (department),
        (reason_desc),
        ()
    )
),
with_rank AS (
    SELECT
        department,
        reason_desc,
        total_return_amount,
        total_net_profit,
        profit_sign,
        RANK() OVER (PARTITION BY department ORDER BY total_net_profit DESC) AS profit_rank,
        g_dept,
        g_reason,
        (SELECT AVG(cs_net_profit) FROM catalog_sales) AS avg_overall_profit
    FROM agg
)
SELECT department,
       reason_desc,
       total_return_amount,
       total_net_profit,
       profit_sign,
       profit_rank,
       avg_overall_profit
FROM with_rank
WHERE (g_dept = 0 OR g_reason = 0)

UNION DISTINCT

SELECT department,
       reason_desc,
       total_return_amount,
       total_net_profit,
       profit_sign,
       profit_rank,
       avg_overall_profit
FROM (
    SELECT
        department,
        reason_desc,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cs_net_profit) AS total_net_profit,
        CASE WHEN SUM(cs_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign,
        GROUPING(department) AS g_dept,
        GROUPING(reason_desc) AS g_reason,
        RANK() OVER (PARTITION BY department ORDER BY SUM(cs_net_profit) DESC) AS profit_rank,
        (SELECT AVG(cs_net_profit) FROM catalog_sales) AS avg_overall_profit
    FROM base
    WHERE cp_type = 'quarterly'
      AND cr_store_credit > 20
      AND c_birth_year < 1960
      AND cs_quantity >= 5
    GROUP BY GROUPING SETS (
        (department, reason_desc),
        (department),
        (reason_desc),
        ()
    )
) q
WHERE (g_dept = 0 OR g_reason = 0)
LIMIT 100
