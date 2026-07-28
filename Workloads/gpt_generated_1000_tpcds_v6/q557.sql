-- Goal: Compare total net paid amounts from catalog and web sales per item category (and per web site when available), rank categories by catalog profit, and flag which channel generated higher revenue.
WITH base AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_net_paid_inc_tax,
        ws.ws_net_paid_inc_ship_tax,
        i.i_category,
        w.web_name,
        cc.cc_state,
        ca.ca_state,
        ib.ib_upper_bound,
        c.c_customer_sk
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE i.i_current_price > 100                       -- predicate 1
      AND cc.cc_state = 'CA'                           -- predicate 2
      AND ca.ca_state = 'TX'                           -- predicate 3
      AND ib.ib_upper_bound <= 100000                 -- predicate 4
      AND cs.cs_net_paid_inc_tax > 500                 -- predicate 5
      AND EXISTS (                                     -- sub‑query predicate
            SELECT 1
            FROM catalog_sales cs2
            WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
              AND cs2.cs_net_paid_inc_tax > 2000
        )
)
SELECT
    i_category,
    web_name,
    SUM(cs_net_paid_inc_tax) AS total_catalog_net_paid,
    SUM(ws_net_paid_inc_ship_tax) AS total_web_net_paid,
    RANK() OVER (ORDER BY SUM(cs_net_paid_inc_tax) DESC) AS catalog_profit_rank,
    CASE
        WHEN SUM(cs_net_paid_inc_tax) > SUM(ws_net_paid_inc_ship_tax) THEN 'CatalogHigher'
        ELSE 'WebHigherOrEqual'
    END AS profit_comparison
FROM base
GROUP BY GROUPING SETS (
    (i_category, web_name),
    (i_category)
)
HAVING SUM(cs_net_paid_inc_tax) > 0
ORDER BY i_category, web_name
LIMIT 100
