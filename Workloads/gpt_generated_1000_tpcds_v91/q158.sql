WITH base AS (
    SELECT
        cc.cc_call_center_id,
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_refunded_cash,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        i.i_product_name,
        hd_refunded.hd_demo_sk   AS hd_refunded_demo_sk,
        hd_refunded.hd_buy_potential AS hd_refunded_buy_potential,
        hd_returning.hd_demo_sk AS hd_returning_demo_sk,
        hd_returning.hd_buy_potential AS hd_returning_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        pr.p_promo_id,
        pr.p_discount_active,
        rsn.r_reason_desc       AS cr_reason_desc,
        rsn2.r_reason_desc      AS sr_reason_desc,
        inv.inv_quantity_on_hand,
        t.t_hour,
        wsite.web_name
    FROM catalog_returns cr
    INNER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    INNER JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    INNER JOIN item i ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    INNER JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    INNER JOIN income_band ib ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN reason rsn ON cr.cr_reason_sk = rsn.r_reason_sk
    CROSS JOIN LATERAL (
        SELECT p.p_promo_id, p.p_discount_active
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
        LIMIT 1
    ) pr
    LEFT JOIN (
        SELECT *
        FROM inventory TABLESAMPLE BERNOULLI (10)
    ) inv ON inv.inv_item_sk = i.i_item_sk
    INNER JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
    INNER JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    INNER JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    INNER JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    INNER JOIN reason rsn2 ON sr.sr_reason_sk = rsn2.r_reason_sk
    INNER JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    INNER JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    INNER JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    INNER JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    INNER JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    INNER JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
),

agg_category AS (
    SELECT
        b.i_category AS group_key,
        SUM(b.ss_ext_sales_price) AS sales_amount,
        SUM(b.sr_net_loss)       AS return_amount
    FROM base b
    WHERE b.i_current_price > 100
      AND b.t_hour BETWEEN 8 AND 18
      AND b.ib_upper_bound >= 60000
      AND b.ws_quantity > 0
    GROUP BY b.i_category
),

agg_brand AS (
    SELECT
        b.i_brand AS group_key,
        SUM(b.ws_ext_sales_price) AS sales_amount,
        SUM(b.cr_return_amount)   AS return_amount
    FROM base b
    WHERE b.i_current_price > 150
      AND b.t_hour BETWEEN 10 AND 20
      AND b.ib_lower_bound <= 50000
      AND b.cr_return_quantity > 0
    GROUP BY b.i_brand
),

union_agg AS (
    SELECT group_key, sales_amount, return_amount FROM agg_category
    UNION
    SELECT group_key, sales_amount, return_amount FROM agg_brand
)

SELECT
    ua.group_key,
    SUM(ua.sales_amount) AS total_sales,
    SUM(ua.return_amount) AS total_returns,
    AVG(ua.sales_amount)  AS avg_sales,
    ROW_NUMBER() OVER (ORDER BY SUM(ua.sales_amount) DESC) AS row_num
FROM union_agg ua
GROUP BY ua.group_key
ORDER BY total_sales DESC
LIMIT 100
