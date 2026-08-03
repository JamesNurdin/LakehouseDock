WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d.d_year,
        i.i_category,
        i.i_brand,
        w.w_state,
        cc.cc_name,
        p.p_promo_name,
        cd.cd_gender,
        hd.hd_buy_potential
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN item i                    ON cs.cs_item_sk       = i.i_item_sk
    JOIN warehouse w               ON cs.cs_warehouse_sk  = w.w_warehouse_sk
    JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p               ON cs.cs_promo_sk      = p.p_promo_sk
    JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr   ON cs.cs_order_number   = cr.cr_order_number
    LEFT JOIN inventory inv        ON inv.inv_item_sk    = i.i_item_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
                                 AND inv.inv_date_sk   = d.d_date_sk
    LEFT JOIN web_sales ws        ON ws.ws_item_sk      = i.i_item_sk
                                 AND ws.ws_warehouse_sk = w.w_warehouse_sk
                                 AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr      ON wr.wr_item_sk      = i.i_item_sk
                                 AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r            ON wr.wr_reason_sk    = r.r_reason_sk
    WHERE d.d_year BETWEEN 1905 AND 1910
      AND i.i_category = 'Sports'
      AND w.w_state = 'CA'
      AND p.p_channel_tv = 'N'
      AND cc.cc_gmt_offset > 0
      AND cd.cd_gender = 'M'
)
SELECT
    d_year,
    i_category,
    w_state,
    SUM(cs_net_paid)   AS total_paid,
    SUM(cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs_order_number) AS order_cnt
FROM base_sales
WHERE cs_order_number NOT IN (
        SELECT cr_order_number
        FROM catalog_returns
        WHERE cr_net_loss > 1000
    )
GROUP BY d_year, i_category, w_state
HAVING SUM(cs_net_paid) > 100000
   AND SUM(cs_net_profit) > (
        SELECT AVG(cs_net_profit)
        FROM catalog_sales
    )
ORDER BY total_profit DESC
LIMIT 100
