WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND ss.ss_ext_discount_amt > 0
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        s.s_store_id,
        i.i_category,
        p.p_promo_name,
        SUM(fs.ss_ext_sales_price) AS total_sales,
        SUM(fs.ss_ext_discount_amt) AS total_discount,
        SUM(fs.ss_net_paid) AS total_net_paid,
        SUM(fs.ss_net_profit) AS total_net_profit,
        AVG(fs.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT fs.ss_customer_sk) AS distinct_customers
    FROM filtered_sales fs
    JOIN store s ON fs.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON fs.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON fs.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON fs.ss_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, d.d_quarter_seq, s.s_store_id, i.i_category, p.p_promo_name
)
SELECT
    d_year,
    d_quarter_seq,
    s_store_id,
    i_category,
    p_promo_name,
    total_sales,
    total_discount,
    total_net_paid,
    total_net_profit,
    avg_discount,
    distinct_customers,
    RANK() OVER (PARTITION BY d_year, s_store_id ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY d_year, s_store_id, profit_rank
LIMIT 200
