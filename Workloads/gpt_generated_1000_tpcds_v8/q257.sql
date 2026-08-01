WITH sales_agg AS (
    SELECT
        ss.ss_ticket_number AS ss_ticket_number,
        s.s_store_id,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'M'
    GROUP BY ss.ss_ticket_number, s.s_store_id, d.d_year
),
returns_agg AS (
    SELECT
        sr.sr_ticket_number AS sr_ticket_number,
        r.r_reason_desc,
        SUM(sr.sr_return_amt_inc_tax) AS total_return,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr ON sr.sr_ticket_number = wr.wr_order_number
    WHERE d.d_year = 2002
      AND s.s_state = 'CA'
      AND r.r_reason_desc = 'Damaged'
    GROUP BY sr.sr_ticket_number, r.r_reason_desc
),
intersect_keys AS (
    SELECT ss_ticket_number AS ticket_number FROM sales_agg
    INTERSECT
    SELECT sr_ticket_number FROM returns_agg
),
except_keys AS (
    SELECT ticket_number FROM intersect_keys
    EXCEPT
    SELECT sr_ticket_number FROM returns_agg WHERE total_return > 5000
)
SELECT
    sa.s_store_id,
    sa.d_year,
    sa.total_sales,
    ra.total_return,
    (sa.total_sales - COALESCE(ra.total_return, 0)) AS net_sales,
    sa.sales_cnt,
    ra.return_cnt,
    sa.sales_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra ON sa.ss_ticket_number = ra.sr_ticket_number
WHERE sa.ss_ticket_number IN (SELECT ticket_number FROM except_keys)
ORDER BY net_sales DESC
OFFSET 0 LIMIT 100
