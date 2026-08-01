WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_warehouse_sk,
        cs.cs_ship_hdemo_sk,
        d_sold.d_year,
        d_sold.d_month_seq,
        wp.wp_type,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM catalog_sales cs
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
        AND wp.wp_max_ad_count = 2
        AND wp.wp_autogen_flag = 'N'
    LEFT JOIN web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cs.cs_warehouse_sk = 7
      AND cs.cs_ship_hdemo_sk = 4418
      AND d_sold.d_year = 1998
      AND d_sold.d_fy_quarter_seq = 8
)
SELECT
    d_year,
    d_month_seq,
    cs_warehouse_sk,
    COALESCE(wp_type, 'UNKNOWN') AS page_type,
    SUM(cs_ext_sales_price) AS total_sales_amount,
    SUM(COALESCE(wr_return_amt, 0)) AS total_returns_amount,
    SUM(cs_net_profit) - SUM(COALESCE(wr_net_loss, 0)) AS net_profit,
    AVG(cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(cs_quantity) AS total_quantity_sold,
    COUNT(DISTINCT cs_item_sk) AS distinct_items,
    CASE WHEN SUM(cs_net_profit) - SUM(COALESCE(wr_net_loss, 0)) > 0 THEN 'POS' ELSE 'NEG' END AS profit_category
FROM filtered_sales
GROUP BY d_year, d_month_seq, cs_warehouse_sk, COALESCE(wp_type, 'UNKNOWN')
ORDER BY total_sales_amount DESC
LIMIT 100
