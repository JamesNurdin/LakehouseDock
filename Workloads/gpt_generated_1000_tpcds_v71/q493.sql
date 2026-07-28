WITH joined_data AS (
    SELECT
        ca.ca_state,
        d.d_year,
        d.d_date,
        p.p_promo_id,
        p.p_channel_tv,
        hd.hd_dep_count,
        cs.cs_quantity,
        ss.ss_net_profit,
        cs.cs_ext_sales_price AS catalog_sales_amount,
        ss.ss_net_profit AS store_profit,
        wr.wr_return_amt AS return_amount,
        wr.wr_return_quantity
    FROM store_sales ss
    INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    INNER JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE
        d.d_date >= DATE '2001-01-01'
        AND d.d_date < DATE '2002-01-01'
        AND p.p_channel_tv = 'N'
        AND hd.hd_dep_count >= 2
        AND cs.cs_quantity > 1
        AND ss.ss_net_profit > 0
        AND wr.wr_return_quantity = 1
),
agg_data AS (
    SELECT
        ca_state,
        d_year,
        p_promo_id,
        SUM(catalog_sales_amount) AS total_catalog_sales,
        SUM(store_profit) AS total_store_profit,
        SUM(return_amount) AS total_returns,
        COUNT(*) AS txn_count
    FROM joined_data
    GROUP BY ca_state, d_year, p_promo_id
    HAVING SUM(catalog_sales_amount) > 10000
       AND SUM(store_profit) > 5000
)
SELECT
    ca_state,
    d_year,
    p_promo_id,
    total_catalog_sales,
    total_store_profit,
    total_returns,
    txn_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_catalog_sales DESC) AS sales_rank,
    AVG(total_catalog_sales) OVER (PARTITION BY d_year) AS avg_sales_year
FROM agg_data
WHERE total_returns < 20000
ORDER BY d_year, sales_rank
LIMIT 100
