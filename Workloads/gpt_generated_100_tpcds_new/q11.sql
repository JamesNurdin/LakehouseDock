WITH base AS (
    SELECT
        t.t_time_sk,
        t.t_hour,
        i.i_item_id,
        i.i_category_id,
        i.i_brand,
        s.s_store_id,
        s.s_state,
        s.s_market_id,
        sr.sr_return_amt,
        cr.cr_return_amount,
        ws.ws_net_profit,
        ws.ws_wholesale_cost,
        wr.wr_return_ship_cost
    FROM tpcds.time_dim t
    JOIN tpcds.store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN tpcds.store s
        ON s.s_store_sk = sr.sr_store_sk
    JOIN tpcds.item i
        ON i.i_item_sk = sr.sr_item_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE t.t_hour BETWEEN 9 AND 17
      AND i.i_category_id IN (8, 9)
      AND s.s_state = 'CA'
      AND cr.cr_return_quantity > 1
      AND ws.ws_wholesale_cost > 30
      AND wr.wr_return_ship_cost > 500
),
agg AS (
    SELECT
        i_item_id,
        s_store_id,
        i_category_id,
        SUM(sr_return_amt) AS total_store_return_amount,
        SUM(cr_return_amount) AS total_catalog_return_amount,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT i_brand) AS distinct_brands,
        COUNT(DISTINCT s_market_id) AS distinct_markets
    FROM base
    GROUP BY i_item_id, s_store_id, i_category_id
)
SELECT
    i_item_id,
    s_store_id,
    i_category_id,
    total_store_return_amount,
    total_catalog_return_amount,
    total_net_profit,
    distinct_brands,
    distinct_markets,
    AVG(total_store_return_amount) OVER (PARTITION BY i_category_id) AS avg_store_return_by_category,
    ROW_NUMBER() OVER (PARTITION BY i_category_id ORDER BY total_store_return_amount DESC) AS rank_within_category
FROM agg
WHERE total_net_profit > 0
ORDER BY i_category_id, rank_within_category
LIMIT 100
