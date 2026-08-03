WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_year,
        d.d_month_seq,
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        i.i_size,
        i.i_color,
        cc.cc_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand,
        r.r_reason_desc,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_net_profit AS cs_net_profit,
        CASE WHEN ss.ss_net_profit > 100 THEN 'High' ELSE 'Low' END AS profit_category
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk AND cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND i.i_size = 'medium'
      AND cc.cc_state = 'CA'
      AND r.r_reason_desc = 'Damaged'
      AND inv.inv_quantity_on_hand > 0
      AND cd.cd_gender = 'M'
)
SELECT
    b.d_year,
    b.i_category,
    b.i_item_id,
    b.profit_category,
    b.ss_quantity,
    b.ss_net_paid,
    b.ss_net_profit,
    b.sr_return_quantity,
    b.sr_net_loss,
    b.inv_quantity_on_hand,
    b.max_item_net_paid,
    ROW_NUMBER() OVER (PARTITION BY b.i_category ORDER BY b.ss_net_paid DESC) AS category_rank,
    AVG(b.ss_net_paid) OVER (PARTITION BY b.i_category) AS avg_category_net_paid
FROM (
    SELECT
        b.*,
        (
            SELECT MAX(cs_sub.cs_net_paid)
            FROM catalog_sales cs_sub
            WHERE cs_sub.cs_item_sk = b.i_item_sk
        ) AS max_item_net_paid
    FROM base b
) b
ORDER BY b.ss_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
