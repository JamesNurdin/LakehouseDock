WITH promo_channels AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        ARRAY[ p.p_channel_email, p.p_channel_tv, p.p_channel_radio, p.p_channel_press ] AS channels
    FROM promotion p
),
base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        d_sold.d_year AS sold_year,
        i.i_item_id,
        i.i_product_name,
        pc.p_promo_name,
        channel,
        cs.cs_net_profit,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        c.c_customer_id,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        w.w_warehouse_name,
        st.s_store_name,
        rc.r_reason_desc,
        ws.web_name,
        inv.inv_quantity_on_hand
    FROM
        catalog_sales cs
        -- Sample a fraction of the item dimension
        JOIN (SELECT * FROM item TABLESAMPLE BERNOULLI (10)) i ON cs.cs_item_sk = i.i_item_sk
        JOIN promo_channels pc ON cs.cs_promo_sk = pc.p_promo_sk
        CROSS JOIN UNNEST(pc.channels) AS t(channel)
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        LEFT JOIN store_returns sr ON cs.cs_item_sk = sr.sr_item_sk
        LEFT JOIN web_returns wr ON cs.cs_item_sk = wr.wr_item_sk
        LEFT JOIN store st ON sr.sr_store_sk = st.s_store_sk
        LEFT JOIN reason rc ON cr.cr_reason_sk = rc.r_reason_sk
                         OR sr.sr_reason_sk = rc.r_reason_sk
                         OR wr.wr_reason_sk = rc.r_reason_sk
        LEFT JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
        LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
                                   OR wr.wr_returned_date_sk = d_return.d_date_sk
        -- Join inventory to bring in on‑hand quantity
        LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                               AND inv.inv_warehouse_sk = w.w_warehouse_sk
                               AND inv.inv_date_sk = d_sold.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND cs.cs_net_paid > (
            SELECT AVG(cs2.cs_net_paid)
            FROM catalog_sales cs2
            WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk
        )
        AND channel = 'Y'
),
agg AS (
    SELECT
        sold_year,
        i_item_id,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS orders
    FROM base
    GROUP BY sold_year, i_item_id
),
positive AS (
    SELECT * FROM agg WHERE total_profit > 0
),
nonpositive AS (
    SELECT * FROM agg WHERE total_profit <= 0
),
union_set AS (
    SELECT * FROM positive
    UNION DISTINCT
    SELECT * FROM nonpositive
),
negative_high_return AS (
    SELECT DISTINCT
        d_ret.d_year AS sold_year,
        i_ret.i_item_id
    FROM catalog_returns cr_ret
    JOIN date_dim d_ret ON cr_ret.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i_ret ON cr_ret.cr_item_sk = i_ret.i_item_sk
    WHERE cr_ret.cr_return_amount > 200
)
SELECT
    u.sold_year,
    u.i_item_id,
    u.total_profit,
    u.orders
FROM union_set u
EXCEPT
SELECT
    u.sold_year,
    u.i_item_id,
    u.total_profit,
    u.orders
FROM union_set u
JOIN negative_high_return nh ON u.sold_year = nh.sold_year
                              AND u.i_item_id = nh.i_item_id
WHERE u.total_profit < 0
ORDER BY
    sold_year,
    i_item_id
