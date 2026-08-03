WITH filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_list_price,
        cs.cs_quantity,
        cd.cd_gender,
        ib.ib_lower_bound,
        wsite.web_tax_percentage,
        ws.ws_net_paid,
        ws.ws_list_price,
        wsite.web_name,
        CASE WHEN cs.cs_net_profit > 100 THEN 'High' ELSE 'Low' END AS profit_category
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    RIGHT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE cs.cs_list_price > 100
      AND cs.cs_quantity >= 2
      AND cd.cd_gender = 'M'
      AND ib.ib_lower_bound >= 50000
      AND wsite.web_tax_percentage <= 0.08
      AND ws.ws_list_price BETWEEN 150 AND 250
      AND cs.cs_order_number NOT IN (SELECT DISTINCT sr_ticket_number FROM store_returns)
)
SELECT
    profit_category,
    web_name,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(ws_net_paid) AS avg_web_paid,
    MIN(cs_list_price) AS min_list_price,
    MAX(cs_list_price) AS max_list_price
FROM filtered
GROUP BY ROLLUP (profit_category, web_name)
ORDER BY profit_category, web_name
LIMIT 100
