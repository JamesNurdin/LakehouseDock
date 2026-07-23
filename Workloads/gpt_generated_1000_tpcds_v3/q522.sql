WITH web_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        ca.ca_state,
        hd.hd_buy_potential,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
        COUNT(DISTINCT ws.ws_web_site_sk) AS distinct_web_sites
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE i.i_color IN ('turquoise', 'pink')
      AND i.i_current_price BETWEEN 5 AND 30
      AND ws.ws_net_paid_inc_tax > 1000
      AND hd.hd_buy_potential = '1001-5000'
      AND ca.ca_state = 'CA'
      AND wp.wp_type = 'product'
    GROUP BY i.i_item_id, i.i_product_name, ca.ca_state, hd.hd_buy_potential
),
catalog_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        ca.ca_state,
        hd.hd_buy_potential,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
        SUM(cs.cs_net_profit) AS total_catalog_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_color IN ('turquoise', 'pink')
      AND i.i_current_price BETWEEN 5 AND 30
      AND cs.cs_net_paid_inc_tax > 500
      AND hd.hd_buy_potential = '1001-5000'
      AND ca.ca_state = 'CA'
    GROUP BY i.i_item_id, i.i_product_name, ca.ca_state, hd.hd_buy_potential
)
SELECT
    wa.i_item_id,
    wa.i_product_name,
    wa.ca_state,
    wa.hd_buy_potential,
    wa.total_web_sales,
    ca.total_catalog_sales,
    wa.total_web_profit,
    ca.total_catalog_profit,
    (wa.total_web_profit + ca.total_catalog_profit) / (wa.total_web_sales + ca.total_catalog_sales) AS profit_margin_ratio,
    wa.distinct_web_pages,
    wa.distinct_web_sites
FROM web_agg wa
JOIN catalog_agg ca
    ON wa.i_item_id = ca.i_item_id
    AND wa.ca_state = ca.ca_state
    AND wa.hd_buy_potential = ca.hd_buy_potential
WHERE (wa.total_web_sales + ca.total_catalog_sales) > 5000
ORDER BY profit_margin_ratio DESC
LIMIT 100
