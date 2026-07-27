WITH ws AS (
    SELECT ws.*, d_sold.d_year
    FROM web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND ws.ws_ext_list_price > 500
      AND ws.ws_net_paid > 100
), ws_sm AS (
    SELECT ws.*, sm.sm_type, sm.sm_code
    FROM ws
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type IN ('EXPRESS', 'REGULAR')
), ws_sm_wh AS (
    SELECT ws_sm.*, wh.w_warehouse_name, wh.w_state
    FROM ws_sm
    JOIN warehouse wh
      ON ws_sm.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE wh.w_state = 'CA'
), ws_sm_wh_inv AS (
    SELECT ws_sm_wh.*, inv.inv_quantity_on_hand, d_inv.d_year AS inv_year
    FROM ws_sm_wh
    JOIN inventory inv
      ON inv.inv_warehouse_sk = ws_sm_wh.ws_warehouse_sk
    JOIN date_dim d_inv
      ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_year = 2001
      AND inv.inv_quantity_on_hand > 0
), ws_sm_wh_inv_promo AS (
    SELECT ws_sm_wh_inv.*, p.p_promo_name, p.p_discount_active, d_promo_start.d_month_seq
    FROM ws_sm_wh_inv
    JOIN promotion p
      ON ws_sm_wh_inv.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
      ON p.p_start_date_sk = d_promo_start.d_date_sk
    WHERE d_promo_start.d_month_seq = 12
      AND p.p_discount_active = 'Y'
), ws_sm_wh_inv_promo_site AS (
    SELECT ws_sm_wh_inv_promo.*, s.web_name
    FROM ws_sm_wh_inv_promo
    JOIN web_site s
      ON ws_sm_wh_inv_promo.ws_web_site_sk = s.web_site_sk
    WHERE s.web_name LIKE '%Shop%'
), ws_full AS (
    SELECT ws_sm_wh_inv_promo_site.*, cd.cd_gender, cd.cd_education_status
    FROM ws_sm_wh_inv_promo_site
    JOIN customer_demographics cd
      ON ws_sm_wh_inv_promo_site.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_education_status = 'College'
), final AS (
    SELECT ws_full.*, d_ret.d_year AS return_year
    FROM ws_full
    JOIN web_returns wr
      ON ws_full.ws_order_number = wr.wr_order_number
     AND ws_full.ws_item_sk = wr.wr_item_sk
    JOIN date_dim d_ret
      ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
)
SELECT
    ws_order_number,
    ws_sold_date_sk,
    return_year,
    ws_net_paid,
    ws_net_profit,
    w_warehouse_name,
    sm_type,
    cd_gender,
    cd_education_status,
    ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY ws_net_profit DESC) AS profit_rank
FROM final
ORDER BY profit_rank
LIMIT 100
