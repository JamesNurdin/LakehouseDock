WITH store_agg AS (
    SELECT ca.ca_state AS state,
           SUM(ss.ss_sales_price) AS store_sales,
           SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk = 5
    GROUP BY ca.ca_state
),
catalog_agg AS (
    SELECT ca.ca_state AS state,
           SUM(cs.cs_sales_price) AS catalog_sales,
           SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE hd.hd_income_band_sk = 5
      AND cc.cc_company_name = 'cally'
    GROUP BY ca.ca_state
),
web_agg AS (
    SELECT ca.ca_state AS state,
           SUM(ws.ws_sales_price) AS web_sales,
           SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE hd.hd_income_band_sk = 5
    GROUP BY ca.ca_state
)
SELECT
    COALESCE(s.state, c.state, w.state) AS state,
    COALESCE(s.store_sales, 0) + COALESCE(c.catalog_sales, 0) + COALESCE(w.web_sales, 0) AS total_sales,
    COALESCE(s.store_profit, 0) + COALESCE(c.catalog_profit, 0) + COALESCE(w.web_profit, 0) AS total_profit,
    ROUND(
        (COALESCE(s.store_profit, 0) + COALESCE(c.catalog_profit, 0) + COALESCE(w.web_profit, 0))
        / NULLIF(COALESCE(s.store_sales, 0) + COALESCE(c.catalog_sales, 0) + COALESCE(w.web_sales, 0), 0),
        4) AS profit_margin,
    RANK() OVER (ORDER BY (COALESCE(s.store_profit, 0) + COALESCE(c.catalog_profit, 0) + COALESCE(w.web_profit, 0)) DESC) AS profit_rank
FROM store_agg s
FULL OUTER JOIN catalog_agg c ON s.state = c.state
FULL OUTER JOIN web_agg w ON COALESCE(s.state, c.state) = w.state
WHERE (COALESCE(s.store_sales, 0) + COALESCE(c.catalog_sales, 0) + COALESCE(w.web_sales, 0)) > 100000
ORDER BY total_profit DESC
LIMIT 10
