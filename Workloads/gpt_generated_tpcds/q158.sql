WITH daily_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        t.t_shift,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_ext_list_price,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    i_brand,
    t_shift,
    sum(ss_quantity) AS total_quantity,
    sum(ss_ext_sales_price) AS total_sales,
    sum(ss_net_paid) AS total_net_paid,
    sum(ss_net_profit) AS total_net_profit,
    avg(ss_ext_discount_amt) AS avg_discount_amount,
    avg(ss_ext_discount_amt / nullif(ss_ext_list_price, 0) * 100) AS avg_discount_percent,
    sum(ss_ext_sales_price) / nullif(sum(ss_quantity), 0) AS avg_price_per_unit
FROM daily_sales
GROUP BY d_year, d_month_seq, i_category, i_brand, t_shift
ORDER BY total_sales DESC
LIMIT 20
