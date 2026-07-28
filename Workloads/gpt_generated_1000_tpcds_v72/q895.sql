WITH agg AS (
    SELECT
        d.d_year,
        i.i_brand,
        cc.cc_state,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(sr.sr_net_loss) AS total_store_returns_loss,
        SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_qty
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND ib.ib_upper_bound >= 150000
      AND cc.cc_state = 'CA'
      AND wsite.web_country = 'United States'
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY d.d_year, i.i_brand, cc.cc_state
)
SELECT
    state,
    AVG(total_sales) AS avg_total_sales,
    AVG(net_sales) AS avg_net_sales
FROM (
    SELECT
        d_year,
        i_brand,
        cc_state AS state,
        total_store_sales,
        total_catalog_sales,
        total_web_sales,
        total_store_returns_loss,
        total_catalog_returns_loss,
        total_inventory_qty,
        (total_store_sales + total_catalog_sales + total_web_sales) AS total_sales,
        (total_store_sales + total_catalog_sales + total_web_sales) - (total_store_returns_loss + total_catalog_returns_loss) AS net_sales
    FROM agg
) sub
GROUP BY state
HAVING AVG(total_sales) > 1000000
ORDER BY avg_net_sales DESC
LIMIT 100
