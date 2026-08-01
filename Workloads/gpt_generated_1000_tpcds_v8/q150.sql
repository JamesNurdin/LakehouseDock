WITH joined AS (
    SELECT
        ss.ss_net_paid,
        ss.ss_quantity,
        p.p_promo_id,
        p.p_promo_name,
        cp.cp_catalog_page_id,
        d_sale.d_date,
        d_sale.d_year,
        d_sale.d_moy,
        wr.wr_return_amt_inc_tax
    FROM store_sales ss
    JOIN date_dim d_sale
        ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN time_dim t_sale
        ON ss.ss_sold_time_sk = t_sale.t_time_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN customer_address ca_sale
        ON ss.ss_addr_sk = ca_sale.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sale.d_date_sk
           AND wr.wr_returned_time_sk = t_sale.t_time_sk
           AND wr.wr_refunded_addr_sk = ca_sale.ca_address_sk
    JOIN catalog_page cp
        ON TRUE
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE d_sale.d_moy = 11
      AND p.p_channel_demo = 'N'
),
agg AS (
    SELECT
        p_promo_id,
        p_promo_name,
        cp_catalog_page_id,
        d_date,
        SUM(ss_net_paid) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        SUM(wr_return_amt_inc_tax) AS total_returns
    FROM joined
    GROUP BY p_promo_id, p_promo_name, cp_catalog_page_id, d_date
)
SELECT
    p_promo_id,
    p_promo_name,
    cp_catalog_page_id,
    d_date AS sale_date,
    total_sales,
    total_quantity,
    total_returns,
    total_sales - COALESCE(total_returns, 0) AS net_contribution,
    SUM(total_sales) OVER (PARTITION BY p_promo_id ORDER BY d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales,
    LAG(total_sales) OVER (PARTITION BY p_promo_id ORDER BY d_date) AS prev_day_sales
FROM agg
ORDER BY p_promo_id, sale_date
LIMIT 100
