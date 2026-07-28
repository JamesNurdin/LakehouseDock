WITH
-- Catalog Sales per item and promotion (includes call_center and income band)
cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cc.cc_name               AS call_center_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_net_paid)      AS cat_sales_net_paid,
        SUM(cs.cs_quantity)      AS cat_sales_qty
    FROM catalog_sales cs
    JOIN time_dim td_cs          ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN customer c_cs           ON cs.cs_bill_customer_sk = c_cs.c_customer_sk
    JOIN customer_demographics cd_cs ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
    JOIN household_demographics hd_cs ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN call_center cc          ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w_cs          ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    JOIN promotion p_cs          ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN income_band ib          ON hd_cs.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY cs.cs_item_sk, cs.cs_promo_sk, cc.cc_name, ib.ib_lower_bound, ib.ib_upper_bound
),

-- Catalog Returns per item
cr_agg AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS cat_return_amount,
        SUM(cr.cr_return_quantity) AS cat_return_qty
    FROM catalog_returns cr
    JOIN time_dim td_cr          ON cr.cr_returned_time_sk = td_cr.t_time_sk
    JOIN item i_cr               ON cr.cr_item_sk = i_cr.i_item_sk
    JOIN warehouse w_cr          ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    GROUP BY cr.cr_item_sk
),

-- Store Sales per item and promotion
ss_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_promo_sk,
        SUM(ss.ss_net_paid)      AS store_sales_net_paid,
        SUM(ss.ss_quantity)      AS store_sales_qty
    FROM store_sales ss
    JOIN time_dim td_ss          ON ss.ss_sold_time_sk = td_ss.t_time_sk
    JOIN customer c_ss           ON ss.ss_customer_sk = c_ss.c_customer_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN promotion p_ss          ON ss.ss_promo_sk = p_ss.p_promo_sk
    GROUP BY ss.ss_item_sk, ss.ss_promo_sk
),

-- Web Sales per item, promotion and web site
ws_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_net_paid)      AS web_sales_net_paid,
        SUM(ws.ws_quantity)      AS web_sales_qty
    FROM web_sales ws
    JOIN time_dim td_ws          ON ws.ws_sold_time_sk = td_ws.t_time_sk
    JOIN customer c_ws           ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN promotion p_ws          ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN web_site we             ON ws.ws_web_site_sk = we.web_site_sk
    GROUP BY ws.ws_item_sk, ws.ws_promo_sk, ws.ws_web_site_sk
),

-- Web Returns per item (left‑joined later)
wr_agg AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_order_number,
        SUM(wr.wr_return_amt)    AS web_return_amt,
        SUM(wr.wr_return_quantity) AS web_return_qty
    FROM web_returns wr
    JOIN time_dim td_wr          ON wr.wr_returned_time_sk = td_wr.t_time_sk
    GROUP BY wr.wr_item_sk, wr.wr_order_number
)

SELECT
    i.i_item_id,
    i.i_brand,
    i.i_category,
    COALESCE(p1.p_promo_name, p2.p_promo_name, p3.p_promo_name)                AS promo_name,
    we.web_name,
    cs_agg.call_center_name,
    cs_agg.ib_lower_bound,
    cs_agg.ib_upper_bound,
    COALESCE(cs_agg.cat_sales_net_paid, 0)                                     AS cat_sales_net_paid,
    COALESCE(ss_agg.store_sales_net_paid, 0)                                   AS store_sales_net_paid,
    COALESCE(ws_agg.web_sales_net_paid, 0)                                     AS web_sales_net_paid,
    COALESCE(cr_agg.cat_return_amount, 0)                                      AS cat_return_amount,
    COALESCE(wr_agg.web_return_amt, 0)                                         AS web_return_amt,
    (
        COALESCE(cs_agg.cat_sales_net_paid, 0) +
        COALESCE(ss_agg.store_sales_net_paid, 0) +
        COALESCE(ws_agg.web_sales_net_paid, 0) -
        COALESCE(cr_agg.cat_return_amount, 0) -
        COALESCE(wr_agg.web_return_amt, 0)
    )                                                                          AS net_revenue,
    ROW_NUMBER() OVER (ORDER BY (
        COALESCE(cs_agg.cat_sales_net_paid, 0) +
        COALESCE(ss_agg.store_sales_net_paid, 0) +
        COALESCE(ws_agg.web_sales_net_paid, 0)
    ) DESC)                                                                  AS revenue_rank
FROM item i
LEFT JOIN cs_agg   ON i.i_item_sk = cs_agg.cs_item_sk
LEFT JOIN ss_agg   ON i.i_item_sk = ss_agg.ss_item_sk
LEFT JOIN ws_agg   ON i.i_item_sk = ws_agg.ws_item_sk
LEFT JOIN cr_agg   ON i.i_item_sk = cr_agg.cr_item_sk
LEFT JOIN wr_agg   ON i.i_item_sk = wr_agg.wr_item_sk
LEFT JOIN promotion p1 ON cs_agg.cs_promo_sk = p1.p_promo_sk          -- first role of promotion
LEFT JOIN promotion p2 ON ss_agg.ss_promo_sk = p2.p_promo_sk          -- second role (different alias)
LEFT JOIN promotion p3 ON ws_agg.ws_promo_sk = p3.p_promo_sk          -- third role (different alias)
LEFT JOIN web_site we   ON ws_agg.ws_web_site_sk = we.web_site_sk       -- outer join to bring web site info
ORDER BY net_revenue DESC
LIMIT 100
