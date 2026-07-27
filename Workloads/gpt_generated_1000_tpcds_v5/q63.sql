WITH base AS (
    SELECT
        d.d_year,
        i.i_item_id,
        i.i_brand,
        cc.cc_name,
        r.r_reason_desc,
        ss.ss_item_sk,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'importoimporto #2'
      AND cc.cc_state = 'CA'
      AND r.r_reason_id = 'AAAAAAAADAAAAAAA'
)
SELECT
    b.d_year,
    b.i_item_id,
    b.i_brand,
    COALESCE(b.cc_name, 'Unknown') AS call_center_name,
    b.r_reason_desc,
    SUM(b.ss_net_profit) AS total_net_profit,
    (SELECT AVG(ss2.ss_net_profit)
     FROM store_sales ss2
     WHERE ss2.ss_item_sk = b.ss_item_sk) AS avg_item_profit_scalar,
    RANK() OVER (PARTITION BY b.d_year ORDER BY SUM(b.ss_net_profit) DESC) AS profit_rank
FROM base b
GROUP BY
    b.d_year,
    b.i_item_id,
    b.i_brand,
    b.cc_name,
    b.r_reason_desc,
    b.ss_item_sk
ORDER BY profit_rank, b.d_year, b.i_item_id
LIMIT 100
