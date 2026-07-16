WITH filtered_sales AS (
    SELECT
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ca.ca_state,
        d_sold.d_year,
        d_sold.d_month_seq
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE ca.ca_country = 'United States'
      AND p.p_discount_active = 'Y'
      AND d_start.d_fy_year = d_end.d_fy_year
      AND d_sold.d_year = 2020
)
SELECT
    ca_state,
    d_year,
    d_month_seq,
    total_net_profit,
    total_sales,
    avg_discount_amt,
    total_net_profit / sum(total_net_profit) OVER (PARTITION BY d_year, d_month_seq) AS profit_share,
    row_number() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        ca_state,
        d_year,
        d_month_seq,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_ext_discount_amt) AS avg_discount_amt
    FROM filtered_sales
    GROUP BY ca_state, d_year, d_month_seq
) agg
ORDER BY d_year, d_month_seq, profit_rank
