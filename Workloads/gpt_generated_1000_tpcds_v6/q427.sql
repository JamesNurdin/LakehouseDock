WITH catalog_agg AS (
    SELECT
        cs_sold_date_sk,
        SUM(cs_net_profit) AS catalog_net_profit,
        SUM(cs_quantity) AS catalog_quantity
    FROM tpcds.catalog_sales
    WHERE cs_quantity > 5
    GROUP BY cs_sold_date_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    ws.ws_web_site_sk,
    ws.ws_order_number,
    ws.ws_net_profit,
    cat.catalog_net_profit,
    inv.inv_quantity_on_hand,
    sr.sr_store_credit,
    (SELECT AVG(inv2.inv_quantity_on_hand)
       FROM tpcds.inventory inv2
       WHERE inv2.inv_item_sk = inv.inv_item_sk) AS avg_item_quantity,
    RANK() OVER (PARTITION BY d.d_year ORDER BY ws.ws_net_profit DESC) AS profit_rank,
    CASE
        WHEN ws.ws_net_profit > 500 THEN 'High'
        WHEN ws.ws_net_profit > 200 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM tpcds.date_dim d
JOIN catalog_agg cat
    ON cat.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN tpcds.store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN tpcds.web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN tpcds.web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1 AND 12
  AND inv.inv_quantity_on_hand > 0
  AND sr.sr_store_credit >= 50
  AND wsite.web_state = 'CA'
  AND ws.ws_net_profit IS NOT NULL
GROUP BY ROLLUP (
    d.d_year,
    d.d_month_seq,
    ws.ws_web_site_sk,
    ws.ws_order_number,
    ws.ws_net_profit,
    cat.catalog_net_profit,
    inv.inv_quantity_on_hand,
    sr.sr_store_credit,
    inv.inv_item_sk
)
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY d.d_year, d.d_month_seq, profit_rank
LIMIT 100
