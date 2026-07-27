WITH sales_enriched AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ext_ship_cost,
        ws.ws_net_profit,
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month_seq,
        d_ship.d_year AS ship_year,
        d_ship.d_month_seq AS ship_month_seq,
        ca_bill.ca_state AS bill_state,
        ca_bill.ca_county AS bill_county,
        ca_ship.ca_state AS ship_state,
        ca_ship.ca_zip AS ship_zip
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
),
agg_profit AS (
    SELECT
        se.bill_state,
        se.bill_county,
        se.ship_state,
        se.ship_zip,
        se.sold_year,
        se.sold_month_seq,
        SUM(se.ws_net_profit) AS total_profit,
        AVG(se.ws_ext_ship_cost) AS avg_ship_cost,
        COUNT(*) AS orders_cnt,
        se.ws_bill_customer_sk
    FROM sales_enriched se
    WHERE
        se.bill_state IN ('CA', 'TX', 'NY')
        AND se.ship_zip IN ('90419', '77752', '88371')
        AND se.sold_year = 2002
        AND EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_bill_customer_sk = se.ws_bill_customer_sk
              AND ws2.ws_ext_ship_cost > 1000
        )
    GROUP BY
        se.bill_state,
        se.bill_county,
        se.ship_state,
        se.ship_zip,
        se.sold_year,
        se.sold_month_seq,
        se.ws_bill_customer_sk
)
SELECT
    ap.bill_state,
    ap.bill_county,
    ap.ship_state,
    ap.ship_zip,
    ap.sold_year,
    ap.sold_month_seq,
    ap.total_profit,
    ap.avg_ship_cost,
    ap.orders_cnt,
    RANK() OVER (PARTITION BY ap.sold_year ORDER BY ap.total_profit DESC) AS profit_rank_year,
    ROW_NUMBER() OVER (PARTITION BY ap.bill_state ORDER BY ap.total_profit DESC) AS rn_state_profit,
    CASE
        WHEN ap.avg_ship_cost > 1000 THEN 'High Shipping Cost'
        WHEN ap.avg_ship_cost > 500 THEN 'Medium Shipping Cost'
        ELSE 'Low Shipping Cost'
    END AS ship_cost_category
FROM agg_profit ap
ORDER BY ap.total_profit DESC, profit_rank_year
LIMIT 100
