WITH
store_return_agg AS (
    SELECT
        d_sr.d_date AS return_date,
        s.s_store_id AS store_id,
        i.i_item_id AS item_id,
        i.i_category AS category,
        ib_sr.ib_lower_bound AS income_band_lower,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_return_net_loss
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN income_band ib_sr ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
    WHERE d_sr.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND ib_sr.ib_lower_bound >= 50000
    GROUP BY d_sr.d_date, s.s_store_id, i.i_item_id, i.i_category, ib_sr.ib_lower_bound
),
catalog_return_agg AS (
    SELECT
        d_cr.d_date AS return_date,
        CAST(NULL AS varchar) AS store_id,
        i.i_item_id AS item_id,
        i.i_category AS category,
        ib_cr.ib_lower_bound AS income_band_lower,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amt,
        SUM(cr.cr_net_loss) AS total_return_net_loss
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd_cr ON cr.cr_refunded_hdemo_sk = hd_cr.hd_demo_sk
    JOIN income_band ib_cr ON hd_cr.hd_income_band_sk = ib_cr.ib_income_band_sk
    WHERE d_cr.d_year = 2001
      AND cp.cp_type = 'monthly'
      AND i.i_brand = 'Brand#12'
      AND ib_cr.ib_lower_bound >= 50000
    GROUP BY d_cr.d_date, i.i_item_id, i.i_category, ib_cr.ib_lower_bound
),
returns_union AS (
    SELECT
        return_date,
        store_id,
        item_id,
        category,
        income_band_lower,
        total_return_qty,
        total_return_amt,
        total_return_net_loss
    FROM store_return_agg
    UNION ALL
    SELECT
        return_date,
        store_id,
        item_id,
        category,
        income_band_lower,
        total_return_qty,
        total_return_amt,
        total_return_net_loss
    FROM catalog_return_agg
),
web_sales_agg AS (
    SELECT
        d_ws.d_date AS sales_date,
        i.i_item_id AS item_id,
        i.i_category AS category,
        ib_ws.ib_lower_bound AS income_band_lower,
        SUM(ws.ws_quantity) AS total_qty_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN income_band ib_ws ON hd_ws.hd_income_band_sk = ib_ws.ib_income_band_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d_ws.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND i.i_brand = 'Brand#12'
      AND ib_ws.ib_lower_bound >= 50000
    GROUP BY d_ws.d_date, i.i_item_id, i.i_category, ib_ws.ib_lower_bound
)
SELECT
    ru.return_date,
    ru.store_id,
    ru.item_id,
    ru.category,
    ru.income_band_lower,
    ru.total_return_qty,
    ru.total_return_amt,
    ru.total_return_net_loss,
    ws.total_qty_sold,
    ws.total_sales_amount,
    ws.total_net_profit,
    CASE
        WHEN ru.total_return_net_loss > ws.total_net_profit THEN 'Loss Dominates'
        ELSE 'Profit Dominates'
    END AS profit_loss_category,
    RANK() OVER (PARTITION BY ru.store_id ORDER BY ru.total_return_net_loss DESC) AS store_loss_rank,
    SUM(ru.total_return_net_loss) OVER (PARTITION BY ru.store_id ORDER BY ru.return_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_loss
FROM returns_union ru
LEFT JOIN web_sales_agg ws
    ON ru.return_date = ws.sales_date
    AND ru.item_id = ws.item_id
ORDER BY ru.return_date, ru.store_id
