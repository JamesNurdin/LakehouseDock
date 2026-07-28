WITH catalog_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_catalog_page_sk,
        SUM(cs.cs_ext_sales_price) AS catalog_rev,
        SUM(cs.cs_quantity) AS catalog_qty
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_quantity > 0
      AND cs.cs_ext_sales_price > 100
      AND cs.cs_catalog_page_sk IS NOT NULL
    GROUP BY cs.cs_item_sk,
             cs.cs_sold_date_sk,
             cs.cs_sold_time_sk,
             cs.cs_bill_cdemo_sk,
             cs.cs_bill_hdemo_sk,
             cs.cs_catalog_page_sk
),
web_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS web_rev,
        SUM(ws.ws_quantity) AS web_qty
    FROM tpcds.web_sales ws
    WHERE ws.ws_quantity > 0
      AND ws.ws_ext_sales_price > 100
      AND ws.ws_web_page_sk IS NOT NULL
    GROUP BY ws.ws_item_sk,
             ws.ws_sold_date_sk,
             ws.ws_sold_time_sk,
             ws.ws_bill_cdemo_sk,
             ws.ws_bill_hdemo_sk,
             ws.ws_web_page_sk,
             ws.ws_web_site_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d.cd_gender,
    hd.hd_buy_potential,
    td.t_hour,
    cp.cp_catalog_page_number,
    ca.catalog_rev,
    ca.catalog_qty,
    wa.web_rev,
    wa.web_qty,
    (ca.catalog_rev + wa.web_rev) AS total_rev,
    RANK() OVER (PARTITION BY td.t_hour ORDER BY (ca.catalog_rev + wa.web_rev) DESC) AS rev_rank_hour
FROM catalog_agg ca
JOIN web_agg wa
    ON ca.cs_item_sk = wa.ws_item_sk
   AND ca.cs_sold_date_sk = wa.ws_sold_date_sk
   AND ca.cs_sold_time_sk = wa.ws_sold_time_sk
JOIN tpcds.item i
    ON i.i_item_sk = ca.cs_item_sk
JOIN tpcds.catalog_page cp
    ON cp.cp_catalog_page_sk = ca.cs_catalog_page_sk
JOIN tpcds.time_dim td
    ON td.t_time_sk = ca.cs_sold_time_sk
JOIN tpcds.customer_demographics d
    ON d.cd_demo_sk = ca.cs_bill_cdemo_sk
JOIN tpcds.household_demographics hd
    ON hd.hd_demo_sk = ca.cs_bill_hdemo_sk
JOIN tpcds.web_page wp
    ON wp.wp_web_page_sk = wa.ws_web_page_sk
JOIN tpcds.web_site wsit
    ON wsit.web_site_sk = wa.ws_web_site_sk
WHERE cp.cp_type = 'monthly'
  AND i.i_current_price > 20
  AND hd.hd_vehicle_count >= 1
  AND d.cd_marital_status = 'M'
  AND td.t_hour BETWEEN 9 AND 17
  AND wa.web_rev > 500
ORDER BY td.t_hour, rev_rank_hour
