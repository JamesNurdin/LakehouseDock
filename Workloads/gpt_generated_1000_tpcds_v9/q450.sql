/* Goal: Identify the highest‑profit items per promotion, showing cumulative profit, return reasons across sales and returns, and expand each promotion's email channel list. */
WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        i.i_category,
        p.p_promo_name,
        p.p_channel_email,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        r_sr.r_reason_desc AS store_return_reason,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_paid,
        cr.cr_return_amount,
        cr.cr_net_loss AS catalog_return_net_loss,
        r_cr.r_reason_desc AS catalog_return_reason,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        r_wr.r_reason_desc AS web_return_reason,
        cc.cc_name AS call_center_name
    FROM store_sales ss
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r_sr
      ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN catalog_sales cs
      ON cs.cs_item_sk = i.i_item_sk
     AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr
      ON cr.cr_item_sk = i.i_item_sk
     AND cr.cr_order_number = cs.cs_order_number
     AND cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r_cr
      ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
     AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r_wr
      ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE i.i_current_price > 100
      AND sr.sr_return_tax > 20
      AND p.p_channel_email <> 'N'
)
SELECT
    b.i_item_id,
    b.i_product_name,
    b.i_category,
    b.p_promo_name,
    b.call_center_name,
    b.store_return_reason,
    b.catalog_return_reason,
    b.web_return_reason,
    b.ss_net_profit,
    b.cum_net_profit,
    b.profit_rank,
    email_channel
FROM (
    SELECT
        base.*,
        ROW_NUMBER() OVER (PARTITION BY base.i_item_sk ORDER BY base.ss_net_profit DESC) AS profit_rank,
        SUM(base.ss_net_profit) OVER (
            PARTITION BY base.i_item_sk
            ORDER BY base.ss_sold_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_net_profit,
        split(base.p_channel_email, ',') AS email_array
    FROM base
) b
CROSS JOIN UNNEST(b.email_array) AS t(email_channel)
ORDER BY b.profit_rank, b.cum_net_profit DESC
LIMIT 100
