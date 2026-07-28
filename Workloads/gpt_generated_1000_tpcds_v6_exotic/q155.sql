WITH base AS (
    SELECT
        s.s_store_name,
        d.d_year,
        i.i_category,
        i.i_current_price,
        i.i_item_id,
        ss.ss_net_profit AS ss_profit,
        ws.ws_net_profit AS ws_profit,
        ss.ss_ext_discount_amt AS ss_discount,
        ws.ws_ext_discount_amt AS ws_discount,
        ss.ss_quantity,
        ss.ss_item_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND s.s_market_manager = 'Edward Stone'
      AND hd.hd_vehicle_count >= 2
      AND i.i_formulation = '883208731996blue7862'
),
cat_avg AS (
    SELECT i_category, AVG(i_current_price) AS cat_avg_price
    FROM item
    GROUP BY i_category
),
agg AS (
    SELECT
        b.s_store_name,
        b.d_year,
        SUM(COALESCE(b.ss_profit, 0) + COALESCE(b.ws_profit, 0)) AS total_profit,
        AVG(b.ss_discount) AS avg_store_discount,
        AVG(b.ws_discount) AS avg_web_discount,
        COUNT(DISTINCT b.i_item_id) AS distinct_items_sold,
        MIN(b.i_current_price) AS min_price,
        MAX(b.i_current_price) AS max_price,
        ca.cat_avg_price,
        MAX(CASE WHEN b.ss_quantity > 5 THEN 1 ELSE 0 END) AS high_quantity_flag
    FROM base b
    JOIN cat_avg ca ON b.i_category = ca.i_category
    GROUP BY b.s_store_name, b.d_year, ca.cat_avg_price
)
SELECT
    a.s_store_name,
    a.d_year,
    a.total_profit,
    a.avg_store_discount,
    a.avg_web_discount,
    a.distinct_items_sold,
    a.min_price,
    a.max_price,
    a.cat_avg_price,
    a.high_quantity_flag,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_profit DESC) AS profit_rank,
    (
        SELECT SUM(ws2.ws_net_profit)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = a.d_year
    ) AS total_web_profit_year
FROM agg a
WHERE a.total_profit > 0
ORDER BY a.d_year, profit_rank
LIMIT 100
