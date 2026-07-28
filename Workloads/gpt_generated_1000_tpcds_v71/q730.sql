WITH joined_data AS (
    SELECT
        ss.ss_item_sk,
        i.i_item_id,
        i.i_product_name,
        ca_ss.ca_state,
        ca_ss.ca_city,
        ca_ss.ca_gmt_offset,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        p_ss.p_promo_name AS store_promo,
        p_ws.p_promo_name AS web_promo,
        w.w_warehouse_name,
        ss.ss_sold_date_sk,
        ws.ws_sold_date_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    JOIN customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
    JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    WHERE ca_ss.ca_city = 'Oakland'
      AND ca_ss.ca_gmt_offset = -5.00
      AND i.i_rec_start_date >= DATE '1998-01-01'
      AND i.i_rec_start_date <= DATE '1998-12-31'
      AND ss.ss_sales_price > 10
),
store_agg AS (
    SELECT
        i_item_id,
        ca_state,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit
    FROM joined_data
    GROUP BY ROLLUP (i_item_id, ca_state)
    HAVING SUM(ss_ext_sales_price) > 0
),
web_agg AS (
    SELECT
        i_item_id,
        ca_state,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM joined_data
    GROUP BY CUBE (i_item_id, ca_state)
    HAVING SUM(ws_ext_sales_price) > 0
),
store_ranked AS (
    SELECT
        i_item_id,
        ca_state,
        total_sales,
        total_profit,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_rank,
        'store' AS channel
    FROM store_agg
),
web_ranked AS (
    SELECT
        i_item_id,
        ca_state,
        total_sales,
        total_profit,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_rank,
        'web' AS channel
    FROM web_agg
)
SELECT i_item_id,
       ca_state,
       total_sales,
       total_profit,
       sales_rank,
       channel
FROM store_ranked
UNION ALL
SELECT i_item_id,
       ca_state,
       total_sales,
       total_profit,
       sales_rank,
       channel
FROM web_ranked
ORDER BY channel, ca_state, sales_rank
LIMIT 100
