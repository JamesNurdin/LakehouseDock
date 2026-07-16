WITH promo_agg AS (
    SELECT
        p.p_promo_name,
        p.p_channel_event,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages,
        MIN(d_sold.d_year) AS first_sale_year,
        MAX(d_sold.d_year) AS last_sale_year
    FROM promotion p
    JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE p.p_discount_active = 'Y'
      AND d_sold.d_date BETWEEN d_start.d_date AND d_end.d_date
      AND d_sold.d_year BETWEEN 2000 AND 2002
      AND cc.cc_state = 'CA'
      AND w.w_state = 'CA'
    GROUP BY p.p_promo_name, p.p_channel_event
    HAVING SUM(cs.cs_net_profit) > 0
)
SELECT
    p.*, 
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM promo_agg p
ORDER BY total_profit DESC
LIMIT 50
