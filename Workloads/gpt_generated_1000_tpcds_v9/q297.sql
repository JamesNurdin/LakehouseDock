WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_wholesale_cost,
        cs.cs_quantity,
        cs.cs_sold_date_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_sales_price,
        ws.ws_quantity,
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        cc.cc_name,
        sm.sm_type,
        sm.sm_ship_mode_id,
        ca_cs.ca_state AS cs_state,
        ca_ws.ca_state AS ws_state,
        hd_cs.hd_income_band_sk,
        ib.ib_upper_bound,
        wsite.web_state,
        wsite.web_name,
        sr.sr_return_quantity,
        wr.wr_return_quantity
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_cs ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN customer_address ca_cs ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
    JOIN income_band ib ON hd_cs.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_hdemo_sk = hd_cs.hd_demo_sk
        AND sr.sr_addr_sk = ca_cs.ca_address_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN customer_address ca_ws ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_rec_end_date <= DATE '2005-12-31'
      AND i.i_rec_start_date >= DATE '2000-01-01'
      AND i.i_current_price BETWEEN 100 AND 500
      AND cs.cs_quantity > 2
      AND cs.cs_wholesale_cost < 50
      AND sm.sm_type = 'AIR'
      AND ib.ib_upper_bound > 60000
      AND wsite.web_state = 'CA'
      AND ws.ws_sales_price > 50
),
catalog_sales_subset AS (
    SELECT
        base.i_item_sk AS item_sk,
        base.i_item_id AS item_id,
        base.cs_order_number AS order_number,
        base.cs_net_paid AS net_paid,
        'catalog' AS sales_channel,
        base.cc_name AS call_center_name
    FROM base
    WHERE base.cs_net_paid > 5000
      AND EXISTS (
          SELECT 1
          FROM store_returns sr_check
          WHERE sr_check.sr_item_sk = base.i_item_sk
            AND sr_check.sr_return_quantity > 0
      )
),
web_sales_subset AS (
    SELECT
        base.i_item_sk AS item_sk,
        base.i_item_id AS item_id,
        base.ws_order_number AS order_number,
        base.ws_net_paid AS net_paid,
        'web' AS sales_channel,
        base.cc_name AS call_center_name
    FROM base
    WHERE base.ws_net_paid > 5000
      AND base.ws_sales_price > 100
),
combined AS (
    SELECT * FROM catalog_sales_subset
    UNION ALL
    SELECT * FROM web_sales_subset
),
final_result AS (
    SELECT
        c.item_sk,
        c.item_id,
        c.sales_channel,
        c.net_paid,
        c.call_center_name,
        RANK() OVER (PARTITION BY c.sales_channel ORDER BY c.net_paid DESC) AS sales_rank,
        (SELECT COALESCE(SUM(sr2.sr_return_quantity), 0)
         FROM store_returns sr2
         WHERE sr2.sr_item_sk = c.item_sk) AS total_return_qty
    FROM combined c
)
SELECT
    item_id,
    sales_channel,
    net_paid,
    call_center_name,
    sales_rank,
    total_return_qty
FROM final_result
ORDER BY sales_rank
LIMIT 100
