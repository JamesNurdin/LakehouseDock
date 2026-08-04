WITH sales_agg AS (
    SELECT
        i.i_brand AS brand,
        wsit.web_name AS website,
        hd_bill.hd_buy_potential AS buy_potential,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(*) AS transaction_cnt,
        CASE WHEN SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE i.i_manufact_id IN (630, 995, 260)
      AND i.i_class_id = 7
      AND cs.cs_ext_list_price > 5000
      AND ws.ws_net_paid_inc_ship_tax < 4000
      AND ib.ib_lower_bound >= 20000
      AND wsit.web_state = 'CA'
    GROUP BY CUBE (i.i_brand, wsit.web_name, hd_bill.hd_buy_potential)
    HAVING COUNT(*) >= 10
)
SELECT
    brand,
    website,
    buy_potential,
    catalog_profit,
    web_profit,
    transaction_cnt,
    profit_category,
    RANK() OVER (PARTITION BY brand ORDER BY (catalog_profit + web_profit) DESC) AS profit_rank,
    SUM(transaction_cnt) OVER (PARTITION BY brand ORDER BY (catalog_profit + web_profit) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_transactions
FROM sales_agg
ORDER BY profit_rank
OFFSET 0 LIMIT 100
