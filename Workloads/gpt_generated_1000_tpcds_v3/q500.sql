WITH base AS (
    SELECT
        s.s_store_name,
        s.s_state,
        i.i_item_id,
        i.i_color,
        i.i_wholesale_cost,
        i.i_item_sk,
        ss.ss_ext_sales_price AS store_sales,
        cs.cs_ext_sales_price AS catalog_sales,
        ws.ws_ext_sales_price AS web_sales,
        cr.cr_return_amount AS catalog_return_amount,
        wr.wr_return_amt AS web_return_amount,
        ss.ss_net_profit AS store_net_profit,
        cs.cs_net_profit AS catalog_net_profit,
        ws.ws_net_profit AS web_net_profit,
        cr.cr_net_loss AS catalog_net_loss,
        wr.wr_net_loss AS web_net_loss,
        ib.ib_upper_bound,
        ib.ib_lower_bound,
        p_ss.p_promo_name AS store_promo_name,
        p_cs.p_promo_name AS catalog_promo_name,
        p_ws.p_promo_name AS web_promo_name,
        r_cr.r_reason_desc AS catalog_return_reason,
        r_wr.r_reason_desc AS web_return_reason
    FROM item i
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    LEFT JOIN income_band ib ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk

    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN customer_demographics cd_cs_bill ON cs.cs_bill_cdemo_sk = cd_cs_bill.cd_demo_sk
    JOIN household_demographics hd_cs_bill ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
    JOIN customer_address ca_cs_bill ON cs.cs_bill_addr_sk = ca_cs_bill.ca_address_sk
    JOIN customer_demographics cd_cs_ship ON cs.cs_ship_cdemo_sk = cd_cs_ship.cd_demo_sk
    JOIN household_demographics hd_cs_ship ON cs.cs_ship_hdemo_sk = hd_cs_ship.hd_demo_sk
    JOIN customer_address ca_cs_ship ON cs.cs_ship_addr_sk = ca_cs_ship.ca_address_sk

    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN customer_demographics cd_cr_refunded ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
    LEFT JOIN household_demographics hd_cr_refunded ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
    LEFT JOIN customer_address ca_cr_refunded ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
    LEFT JOIN customer_demographics cd_cr_returning ON cr.cr_returning_cdemo_sk = cd_cr_returning.cd_demo_sk
    LEFT JOIN household_demographics hd_cr_returning ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
    LEFT JOIN customer_address ca_cr_returning ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk

    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
    JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk

    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    LEFT JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    LEFT JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    LEFT JOIN customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
    LEFT JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    LEFT JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
)
SELECT
    base.s_store_name,
    base.s_state,
    base.i_item_id,
    base.i_color,
    SUM(base.store_sales) AS total_store_sales,
    SUM(base.catalog_sales) AS total_catalog_sales,
    SUM(base.web_sales) AS total_web_sales,
    SUM(base.catalog_return_amount) AS total_catalog_returns,
    SUM(base.web_return_amount) AS total_web_returns,
    SUM(base.store_net_profit) + SUM(base.catalog_net_profit) + SUM(base.web_net_profit)
        - (SUM(base.catalog_net_loss) + SUM(base.web_net_loss)) AS net_profit,
    AVG(base.i_wholesale_cost) AS avg_wholesale_cost,
    COUNT(*) AS transaction_count,
    MAX(base.ib_upper_bound) AS max_income_upper_bound
FROM base
WHERE base.i_color = 'snow'
  AND base.s_state = 'CA'
  AND base.ib_upper_bound >= 50000
  AND EXISTS (
      SELECT 1 FROM promotion p_any
      WHERE p_any.p_item_sk = base.i_item_sk
        AND p_any.p_discount_active = 'Y'
  )
GROUP BY
    base.s_store_name,
    base.s_state,
    base.i_item_id,
    base.i_color
ORDER BY net_profit DESC
LIMIT 100
