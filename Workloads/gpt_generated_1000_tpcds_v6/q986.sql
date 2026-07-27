WITH store_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_cs_sold.d_year AS sales_year,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(sr.sr_net_loss) AS returns_loss,
        (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss)) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d_cs_sold
        ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN date_dim d_cs_ship
        ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_cs_sold.d_date_sk
    JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_cs_sold.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    WHERE
        d_cs_sold.d_year = 2001
        AND cs.cs_quantity > 1
        AND ws.ws_ext_discount_amt > 0
        AND sr.sr_fee > 10
        AND s.s_state = 'CA'
        AND ws.ws_net_paid_inc_ship_tax > 1000
        AND EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_store_sk = s.s_store_sk
              AND sr2.sr_fee > 20
        )
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_cs_sold.d_year
)
SELECT
    ss.s_store_id,
    ss.s_store_name,
    ss.sales_year,
    ss.total_profit,
    ss.catalog_profit,
    ss.web_profit,
    ss.returns_loss
FROM store_sales ss
WHERE ss.total_profit > (
    SELECT AVG(total_profit) FROM store_sales
)
ORDER BY ss.total_profit DESC
LIMIT 100
