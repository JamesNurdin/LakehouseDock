WITH
  base AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_order_number,
      ws.ws_net_profit,
      ws.ws_ext_sales_price,
      i.i_item_sk,
      i.i_category,
      i.i_brand,
      i.i_current_price,
      p.p_promo_id,
      p.p_discount_active,
      w.w_state,
      wp.wp_web_page_id,
      wsit.web_name,
      cr.cr_return_amount,
      sr.sr_return_amt,
      wr.wr_return_amt,
      c.c_customer_id,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_upper_bound
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN tpcds.web_returns wr ON ws.ws_item_sk = wr.wr_item_sk
                                 AND ws.ws_order_number = wr.wr_order_number
    LEFT JOIN tpcds.catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
    LEFT JOIN tpcds.store_returns sr ON i.i_item_sk = sr.sr_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451911 AND 2451915
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND wsit.web_country = 'United States'
  ),
  avg_profit AS (
    SELECT avg(ws_net_profit) AS val FROM tpcds.web_sales
  )
SELECT *
FROM (
  SELECT
    i_category,
    i_brand,
    SUM(ws_net_profit) AS total_amount,
    COUNT(*) AS order_cnt,
    CASE WHEN SUM(ws_net_profit) > (SELECT val FROM avg_profit) THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category,
    ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS rn
  FROM base
  GROUP BY GROUPING SETS ((i_category, i_brand), (i_brand), ())

  UNION DISTINCT

  SELECT
    NULL AS i_category,
    i_brand,
    SUM(cr_return_amount) AS total_amount,
    COUNT(*) AS order_cnt,
    CASE WHEN SUM(cr_return_amount) > 1000 THEN 'High Return' ELSE 'Low Return' END AS profit_category,
    ROW_NUMBER() OVER (ORDER BY SUM(cr_return_amount) DESC) AS rn
  FROM base
  WHERE cr_return_amount IS NOT NULL AND cr_return_amount > 100
  GROUP BY GROUPING SETS ((i_brand), ())
) AS unioned
ORDER BY rn
LIMIT 100
